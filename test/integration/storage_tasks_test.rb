require "test_helper"
require "rake"

class StorageTasksTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("storage:upload_to_supabase")
  end

  test "upload_to_supabase aborts unless the active storage service is supabase" do
    Rake::Task["storage:upload_to_supabase"].reenable

    _out, err = capture_io { assert_raises(SystemExit) { Rake::Task["storage:upload_to_supabase"].invoke } }
    assert_match(/supabase/, err)
  end
end
