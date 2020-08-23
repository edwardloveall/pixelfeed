class AddRefreshTokenToServiceTokens::V20200823202752 < Avram::Migrator::Migration::V1
  def migrate
    alter table_for(ServiceToken) do
      add refresh_token : String?
    end
  end

  def rollback
    alter table_for(ServiceToken) do
      remove :refresh_token
    end
  end
end
