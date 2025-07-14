import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :greenhouse_tycoon, GreenhouseTycoon.Repo,
  database: Path.expand("../regulate_greenhouse_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :manage_crops, ManageCrops.Repo,
  database: Path.expand("../manage_crops_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :procure_supplies, ProcureSupplies.Repo,
  database: Path.expand("../procure_supplies_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :maintain_equipment, MaintainEquipment.Repo,
  database: Path.expand("../maintain_equipment_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :greenhouse_tycoon_web, GreenhouseTycoonWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "DqkAkGqUABN98FzCyPJYWjvZFkTOBSWRHc0LzV63zjacBHurOunJ9rBBPXwKm9pg",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails
config :greenhouse_tycoon, GreenhouseTycoon.Mailer, adapter: Swoosh.Adapters.Test
config :manage_crops, ManageCrops.Mailer, adapter: Swoosh.Adapters.Test
config :procure_supplies, ProcureSupplies.Mailer, adapter: Swoosh.Adapters.Test
config :maintain_equipment, MaintainEquipment.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Individual apps configure their own ExESDB instances for testing

# Individual apps configure their own Commanded applications for testing

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
