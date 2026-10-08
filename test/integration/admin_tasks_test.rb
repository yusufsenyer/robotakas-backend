require "test_helper"
require "rake"

class AdminTasksTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("admin:create")
  end

  teardown do
    %w[ADMIN_EMAIL ADMIN_PASSWORD ADMIN_NAME ADMIN_CITY].each { |key| ENV.delete(key) }
  end

  def invoke(task)
    Rake::Task[task].reenable
    Rake::Task[task].invoke
  end

  test "requires ADMIN_EMAIL" do
    assert_raises(SystemExit) { capture_io { invoke("admin:create") } }
  end

  test "rejects a password shorter than 12 characters" do
    ENV["ADMIN_EMAIL"] = "newadmin@example.com"
    ENV["ADMIN_PASSWORD"] = "kisa"

    assert_raises(SystemExit) { capture_io { invoke("admin:create") } }
    assert_nil User.find_by(email: "newadmin@example.com")
  end

  test "creates an admin, masks the email and never prints the password" do
    ENV["ADMIN_EMAIL"] = "newadmin@example.com"
    ENV["ADMIN_PASSWORD"] = "SuperSecret12345"

    out, _err = capture_io { invoke("admin:create") }

    user = User.find_by(email: "newadmin@example.com")
    assert user
    assert_equal "admin", user.role
    assert user.authenticate("SuperSecret12345")

    assert_includes out, "n•••@example.com"
    refute_includes out, "SuperSecret12345"
    refute_includes out, user.password_digest
  end

  test "is idempotent and rotates the password on the second run" do
    ENV["ADMIN_EMAIL"] = "newadmin@example.com"
    ENV["ADMIN_PASSWORD"] = "SuperSecret12345"

    assert_difference -> { User.count }, 1 do
      capture_io { invoke("admin:create") }
    end

    ENV["ADMIN_PASSWORD"] = "EvenBetterSecret123"

    assert_no_difference -> { User.count } do
      capture_io { invoke("admin:create") }
    end

    assert User.find_by(email: "newadmin@example.com").authenticate("EvenBetterSecret123")
  end
end
