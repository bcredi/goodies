use Mix.Config

appsignal_transaction_module =
  if Mix.env() == :test do
    Appsignal.TransactionMock
  else
    Appsignal.Transaction
  end

config :goodies, appsignal_transaction_module: appsignal_transaction_module
