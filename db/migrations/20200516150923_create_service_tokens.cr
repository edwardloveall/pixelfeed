class CreateServiceTokens::V20200516150923 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(ServiceToken) do
      primary_key id : Int64
      add_timestamps
      add service : String
      add token : String
      add expires_at : Time
    end
  end

  def rollback
    drop table_for(ServiceToken)
  end
end
