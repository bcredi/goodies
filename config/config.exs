use Mix.Config

config :goodies, appsignal_transaction_module: Appsignal.Transaction

if Mix.env() == :test do
  config :goodies, appsignal_transaction_module: Appsignal.TransactionMock
end
