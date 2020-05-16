class SaveServiceToken < ServiceToken::SaveOperation
  permit_columns service, token, expires_at
end
