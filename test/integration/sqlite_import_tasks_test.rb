require "test_helper"
require "rake"

class SqliteImportTasksTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("db:import_from_sqlite")
  end

  teardown do
    ENV.delete("SOURCE_SQLITE")
    FileUtils.rm_f(@source) if @source
  end

  def invoke(task)
    Rake::Task[task].reenable
    Rake::Task[task].invoke
  end

  test "requires SOURCE_SQLITE" do
    _out, err = capture_io { assert_raises(SystemExit) { invoke("db:import_from_sqlite") } }
    assert_match(/SOURCE_SQLITE/, err)
  end

  test "aborts when the source file is missing" do
    ENV["SOURCE_SQLITE"] = "/tmp/missing-#{SecureRandom.hex(4)}.sqlite3"
    _out, err = capture_io { assert_raises(SystemExit) { invoke("db:import_from_sqlite") } }
    assert_match(/bulunamadı/, err)
  end

  test "aborts when the target is not PostgreSQL" do
    @source = Rails.root.join("tmp", "import-source-#{SecureRandom.hex(4)}.sqlite3")
    FileUtils.touch(@source)
    ENV["SOURCE_SQLITE"] = @source.to_s

    connection = ActiveRecord::Base.connection
    connection.define_singleton_method(:adapter_name) { "SQLite" }
    begin
      _out, err = capture_io { assert_raises(SystemExit) { invoke("db:import_from_sqlite") } }
      assert_match(/Postgres/, err)
    ensure
      connection.singleton_class.send(:remove_method, :adapter_name)
    end
  end
end
