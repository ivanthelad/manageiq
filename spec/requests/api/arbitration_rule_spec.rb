RSpec.describe 'Arbitration Rule API' do
  context 'arbitration rules index' do
    it 'rejects requests without an appropriate role' do
      api_basic_authorize

      run_get arbitration_rules_url

      expect(response).to have_http_status(:forbidden)
    end

    it 'can list arbitration rules' do
      rules = FactoryGirl.create_list(:arbitration_rule, 2)
      api_basic_authorize collection_action_identifier(:arbitration_rules, :read, :get)

      run_get arbitration_rules_url

      expect_result_resources_to_include_hrefs(
        'resources',
        rules.map { |rule| arbitration_rules_url(rule.id) }
      )
      expect(response).to have_http_status(:ok)
    end
  end

  context 'arbitration rules create' do
    let(:profile) { FactoryGirl.create(:arbitration_profile) }
    let(:request_body) do
      {
        'description'            => 'admin rule',
        'operation'              => 'inject',
        'arbitration_profile_id' => profile.id,
        'expression'             => {
          'EQUAL' => {
            'field' => 'User-userid',
            'value' => 'admin'
          }
        }
      }
    end

    it 'supports single arbitration_rule creation' do
      api_basic_authorize collection_action_identifier(:arbitration_rules, :create)

      expect do
        run_post(arbitration_rules_url, gen_request(:create, request_body))
      end.to change(ArbitrationRule, :count).by(1)
    end

    it 'supports multiple arbitration_rule creation' do
      api_basic_authorize collection_action_identifier(:arbitration_rules, :create)

      expect do
        run_post(arbitration_rules_url, gen_request(:create, [request_body, request_body]))
      end.to change(ArbitrationRule, :count).by(2)
    end

    it 'rejects a request with an id' do
      api_basic_authorize collection_action_identifier(:arbitration_rules, :create)

      run_post(arbitration_rules_url(999_999), request_body.merge(:id => 999_999))

      expect_bad_request(/Unsupported Action create for the arbitration_rules resource/)
    end
  end

  context 'arbitration rules edit' do
    let(:rule) { FactoryGirl.create(:arbitration_rule) }

    it 'rejects edit without an appropriate role' do
      api_basic_authorize

      run_post(arbitration_rules_url(rule.id), gen_request(:edit, :description => 'edited description'))

      expect(response).to have_http_status(:forbidden)
    end

    it 'can edit a setting' do
      api_basic_authorize collection_action_identifier(:arbitration_rules, :edit)

      expect do
        run_post(arbitration_rules_url(rule.id), gen_request(:edit, :description => 'edited description'))
      end.to change { rule.reload.description }.to('edited description')
    end
  end

  context 'arbitration rules delete' do
    it 'supports single arbitration rule delete' do
      rule = FactoryGirl.create(:arbitration_rule)
      api_basic_authorize collection_action_identifier(:arbitration_rules, :delete)

      expect do
        run_delete(arbitration_rules_url(rule.id))
      end.to change(ArbitrationRule, :count).by(-1)
    end

    it 'supports multiple arbitration rule delete' do
      rules = FactoryGirl.create_list(:arbitration_rule, 2)
      hrefs = rules.map { |rule| { 'href' => arbitration_rules_url(rule.id) } }
      api_basic_authorize collection_action_identifier(:arbitration_rules, :delete)

      expect do
        run_post(arbitration_rules_url, gen_request(:delete, hrefs))
      end.to change(ArbitrationRule, :count).by(-2)
    end
  end

  context 'OPTIONS /api/arbitration_rules' do
    it 'returns arbitration rule field_values' do
      api_basic_authorize

      attributes = (ArbitrationRule.attribute_names - ArbitrationRule.virtual_attribute_names).sort.as_json
      reflections = (ArbitrationRule.reflections.keys | ArbitrationRule.virtual_reflections.keys.collect(&:to_s)).sort
      expected = {
        'attributes'         => attributes,
        'virtual_attributes' => ArbitrationRule.virtual_attribute_names.sort.as_json,
        'relationships'      => reflections,
        'data'               => {
          'field_values' => ArbitrationRule.field_values
        }
      }

      run_options(arbitration_rules_url)
      expect(response.parsed_body).to eq(expected)
      expect(response.headers['Access-Control-Allow-Methods']).to include('OPTIONS')
    end
  end
end
