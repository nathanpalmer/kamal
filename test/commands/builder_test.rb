require "test_helper"
require "mrsk/configuration"
require "mrsk/commands/builder"

class CommandsBuilderTest < ActiveSupport::TestCase
  setup do
    @config = { service: "app", image: "dhh/app", registry: { "username" => "dhh", "password" => "secret" }, servers: [ "1.1.1.1" ] }
  end

  test "target multiarch by default" do
    builder = Mrsk::Commands::Builder.new(Mrsk::Configuration.new(@config))
    assert builder.multiarch?
  end

  test "target native when multiarch is off" do
    builder = Mrsk::Commands::Builder.new(Mrsk::Configuration.new(@config.merge({ builder: { "multiarch" => false } })))
    assert builder.native?
  end

  test "target multiarch remote when local and remote is set" do
    builder = Mrsk::Commands::Builder.new(Mrsk::Configuration.new(@config.merge({ builder: { "local" => { }, "remote" => { } } })))
    assert builder.remote?
  end

  test "build args" do
    builder = Mrsk::Commands::Builder.new(Mrsk::Configuration.new(@config.merge({ builder: { "args" => { "a" => 1, "b" => 2 } } })))
    assert_equal [ "--build-arg", "a=1", "--build-arg", "b=2" ], builder.target.build_args
  end

  test "build secrets" do
    builder = Mrsk::Commands::Builder.new(Mrsk::Configuration.new(@config.merge({ builder: { "secrets" => ["token_a", "token_b"] } })))
    assert_equal [ "--secret", "id=token_a", "--secret", "id=token_b" ], builder.target.build_secrets
  end

  test "native push with build args" do
    builder = Mrsk::Commands::Builder.new(Mrsk::Configuration.new(@config.merge({ builder: { "multiarch" => false, "args" => { "a" => 1, "b" => 2 } } })))
    assert_equal [ :docker, :build, "-t", "--build-arg", "a=1", "--build-arg", "b=2", "dhh/app:123", ".", "&&", :docker, :push, "dhh/app:123" ], builder.push
  end

  test "multiarch push with build args" do
    builder = Mrsk::Commands::Builder.new(Mrsk::Configuration.new(@config.merge({ builder: { "args" => { "a" => 1, "b" => 2 } } })))
    assert_equal [ :docker, :buildx, :build, "--push", "--platform linux/amd64,linux/arm64", "-t", "dhh/app:123", "--build-arg", "a=1", "--build-arg", "b=2", "." ], builder.push
  end

  test "native push with with build secrets" do
    builder = Mrsk::Commands::Builder.new(Mrsk::Configuration.new(@config.merge({ builder: { "multiarch" => false, "secrets" => [ "a", "b" ] } })))
    assert_equal [ :docker, :build, "-t", "--secret", "id=a", "--secret", "id=b", "dhh/app:123", ".", "&&", :docker, :push, "dhh/app:123" ], builder.push
  end
end
