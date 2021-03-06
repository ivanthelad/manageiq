shared_examples "miq ownership" do
  # THIS TOP LEVEL CONTEXT IS REQUIRED because tests that include are database
  # state dependent and require a clean DB.  When used with `include_examples`,
  # the before(:context) and after(:context) in this are run on the same level
  # as the `include_example`'s current context, so more likely than not, it
  # will be included in other tests that aren't part of this example group.
  context "includes mixin:  miq ownership" do
    include Spec::Support::ArelHelper

    let(:user) { User.where(:userid => "ownership_user").first }

    before(:context) do
      build_ownership_users_and_groups
    end

    describe ".owning_ldap_group" do
      before { User.current_user = user }

      context "when miq_group is in the ldap group" do
        it "returns description" do
          column = "owning_ldap_group"
          query  = described_class.where(:name => 'in_ldap')
          expect(virtual_column_sql_value(query, column)).to eq(user.current_group.description)
        end
      end

      context "when miq_group is not in the ldap group" do
        it "returns no description" do
          column = "owning_ldap_group"
          query  = described_class.where(:name => 'no_group')
          expect(virtual_column_sql_value(query, column)).to be_nil
        end
      end
    end

    describe ".owned_by_current_ldap_group" do
      before { User.current_user = user }

      it "usable as arel" do
        group_name = user.current_group.description.downcase
        sql        = <<-SQL.strip_heredoc.split("\n").join(' ')
                       LOWER((SELECT "miq_groups_ss"."description"
                       FROM "miq_groups" "miq_groups_ss"
                       WHERE "miq_groups_ss"."id" = "#{described_class.table_name}"."miq_group_id")) = '#{group_name}'
                     SQL
        attribute  = described_class.arel_attribute(:owned_by_current_ldap_group)
        expect(stringify_arel(attribute)).to eq ["(#{sql})"]
      end

      context "when miq_group is in the ldap group" do
        it "returns true" do
          column = "owned_by_current_ldap_group"
          query  = described_class.where(:name => 'in_ldap')
          expect(virtual_column_sql_value(query, column)).to eq(true)
        end
      end

      context "when miq_group is not in the ldap group" do
        it "returns false" do
          column = "owned_by_current_ldap_group"
          query  = described_class.where(:name => 'not_in_ldap')
          expect(virtual_column_sql_value(query, column)).to eq(false)
        end
      end

      # Since we are doing a regular inner join here, no results will be returned
      # when there isn't an associated miq_group for the record.
      #
      # This was the existing behaviour of the owned_by_current_ldap_group
      # method, so we are testing that the query (even without the
      # virtual_attribute) will return no records.
      context "when miq_group is in no ldap group" do
        it "returns nil" do
          column = "owned_by_current_ldap_group"
          query  = described_class.where(:name => 'no_group')

          expect(virtual_column_sql_value(query, column)).to eq(nil)
        end

        it "returns no results when searching by name and owned_by_current_ldap_group" do
          column = "owned_by_current_ldap_group"
          query  = described_class.where :name  => 'no_group',
                                         column => false
          expect(query.to_a.size).to eq(0)
        end
      end
    end

    describe ".evm_owner_name" do
      before { User.current_user = user }

      context "when has a user" do
        it "returns userid" do
          column = "evm_owner_name"
          query  = described_class.where(:name => 'user_owned')
          expect(virtual_column_sql_value(query, column)).to eq(user.name)
        end
      end

      context "when has no user" do
        it "returns no description" do
          column = "evm_owner_name"
          query  = described_class.where(:name => 'no_group')
          expect(virtual_column_sql_value(query, column)).to be_nil
        end
      end
    end

    describe ".evm_owner_userid" do
      before { User.current_user = user }

      context "when has a user" do
        it "returns userid" do
          column = "evm_owner_userid"
          query  = described_class.where(:name => 'user_owned')
          expect(virtual_column_sql_value(query, column)).to eq(user.userid)
        end
      end

      context "when has no user" do
        it "returns no description" do
          column = "evm_owner_userid"
          query  = described_class.where(:name => 'no_group')
          expect(virtual_column_sql_value(query, column)).to be_nil
        end
      end
    end

    describe ".evm_owner_email" do
      before { User.current_user = user }

      context "when has a user" do
        it "returns userid" do
          column = "evm_owner_email"
          query  = described_class.where(:name => 'user_owned')
          expect(virtual_column_sql_value(query, column)).to eq(user.email)
        end
      end

      context "when has no user" do
        it "returns no description" do
          column = "evm_owner_email"
          query  = described_class.where(:name => 'no_group')
          expect(virtual_column_sql_value(query, column)).to be_nil
        end
      end
    end

    describe ".owned_by_current_user" do
      before { User.current_user = user }
      it "usable as arel" do
        userid = user.userid.downcase
        sql        = <<-SQL.strip_heredoc.split("\n").join(' ')
                       LOWER((SELECT "users_ss"."userid"
                       FROM "users" "users_ss"
                       WHERE "users_ss"."id" = "#{described_class.table_name}"."evm_owner_id")) = '#{userid}'
                     SQL
        attribute  = described_class.arel_attribute(:owned_by_current_user)
        expect(stringify_arel(attribute)).to eq ["(#{sql})"]
      end

      context "when owned by the current user" do
        it "returns true" do
          column = "owned_by_current_user"
          query  = described_class.where(:name => 'user_owned')
          expect(virtual_column_sql_value(query, column)).to eq(true)
        end
      end

      context "when owned by a different user" do
        it "returns false" do
          column = "owned_by_current_user"
          query  = described_class.where(:name => 'user_owned2')
          expect(virtual_column_sql_value(query, column)).to eq(false)
        end
      end

      context "when no user" do
        it "returns nil" do
          column = "owned_by_current_user"
          query  = described_class.where(:name => 'no_group')

          expect(virtual_column_sql_value(query, column)).to eq(nil)
        end

        it "returns no results when searching by name and owned_by_current_user" do
          column = "owned_by_current_user"
          query  = described_class.where :name  => 'no_group',
                                         column => false
          expect(query.to_a.size).to eq(0)
        end
      end
    end

    describe "reporting on ownership" do
      let(:exp_value) { "true" }
      let(:exp) { { "="=> { "field" => "#{described_class}-owned_by_current_ldap_group", "value" => exp_value } } }
      let(:report) { MiqReport.new.tap { |r| r.db = described_class.to_s } }
      let(:search_opts) { { :filter => MiqExpression.new(exp), :per_page => 20 } }
      let(:owned_by_group_1)  { described_class.where(:name => 'in_ldap').first }
      let(:owned_by_group_2)  { described_class.where(:name => 'not_in_ldap').first }
      let(:owned_by_group_3)  { described_class.where(:name => 'no_group').first }
      let(:owned_by_user)     { described_class.where(:name => 'user_owned').first }
      let(:owned_by_user2)    { described_class.where(:name => 'user_owned2').first }

      before do
        expect(User).to receive(:server_timezone).and_return("UTC")

        # Needs to be done after the groups are created, otherwise the
        # described_class will be auto-assigned with the current user's group
        User.current_user = user
      end

      context "searching by records in current ldap group" do
        it "returns results only part of the miq_group" do
          owned_ids = report.paged_view_search(search_opts).first.map(&:id)
          expect(owned_ids).to match_array [owned_by_group_1.id]
        end
      end

      context "searching by records not in current ldap group" do
        let(:exp_value) { "false" }

        it "returns results not part of the miq_group" do
          owned_ids = report.paged_view_search(search_opts).first.map(&:id)
          expect(owned_ids).to match_array [owned_by_group_2.id]
        end
      end

      context "searching on owned by the current user" do
        let(:search_opts) { { :filter => MiqExpression.new(exp), :per_page => 20 } }
        let(:exp) { { "="=> { "field" => "#{described_class}-owned_by_current_user", "value" => "true" } } }

        it "returns results owned by the user" do
          owned_ids = report.paged_view_search(search_opts).first.map(&:id)
          expect(owned_ids).to match_array [owned_by_user.id]
        end
      end

      context "searching on not owned by the current user" do
        let(:search_opts) { { :filter => MiqExpression.new(exp), :per_page => 20 } }
        let(:exp) { { "="=> { "field" => "#{described_class}-owned_by_current_user", "value" => "false" } } }

        it "returns results not owned by the user, but have an owner" do
          owned_ids = report.paged_view_search(search_opts).first.map(&:id)
          expect(owned_ids).to match_array [owned_by_user2.id]
        end
      end
    end

    after(:context) do
      teardown_ownership_users_and_groups
    end

    def build_ownership_users_and_groups
      user = FactoryGirl.create :user,
                                :userid     => "ownership_user",
                                :miq_groups => FactoryGirl.create_list(:miq_group, 1)
      user2 = FactoryGirl.create :user

      factory = described_class.to_s.underscore.to_sym
      FactoryGirl.create factory, :name => "in_ldap",     :miq_group_id => user.current_group.id
      FactoryGirl.create factory, :name => "not_in_ldap", :miq_group => FactoryGirl.create(:miq_group)
      FactoryGirl.create factory, :name => "no_group"
      FactoryGirl.create factory, :name => "user_owned",  :evm_owner => user
      FactoryGirl.create factory, :name => "user_owned2", :evm_owner => user2
    end

    def teardown_ownership_users_and_groups
      described_class.destroy_all
      User.destroy_all
      MiqGroup.destroy_all
    end
  end
end
