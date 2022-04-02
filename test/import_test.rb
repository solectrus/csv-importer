require 'test_helper'

class ImportTest < Minitest::Test
  def test_import
    VCR.use_cassette('import') do
      Import.run(config: Config.from_env)
    end
  end
end
