module FixturesHelper
  def fixture_path(filename)
    File.join(File.dirname(__FILE__), '..', 'fixtures', filename)
  end

  def fixture(filename)
    File.read(fixture_path(filename))
  end

  def json_fixture(filename)
    JSON.parse(fixture(filename))
  end
end

RSpec.configure do |config|
  config.include FixturesHelper
end