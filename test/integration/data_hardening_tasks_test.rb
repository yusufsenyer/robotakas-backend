require "test_helper"
require "rake"

class DataHardeningTasksTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("data:harden")

    @admin = User.create!(
      full_name: "RoboTakas Admin", email: "admin@robotakas.test",
      password: "Admin1234!", city: "Ankara", role: "admin",
    )
    @demo = User.create!(
      full_name: "Efe Kaya", email: "demo1@robotakas.test",
      password: "Demo1234!", city: "Ankara",
    )
    @other = User.create!(
      full_name: "Başka Kişi", email: "other@example.com",
      password: "Other1234!", city: "İzmir",
    )
  end

  teardown do
    %w[OLD_ADMIN_EMAIL DEMO_PASSWORD CONFIRM].each { |key| ENV.delete(key) }
  end

  def invoke(task)
    Rake::Task[task].reenable
    Rake::Task[task].invoke
  end

  test "dry-run changes nothing and lists masked emails" do
    ENV["OLD_ADMIN_EMAIL"] = "admin@robotakas.test"
    ENV["DEMO_PASSWORD"] = "BrandNewDemoPass123"

    out, _err = capture_io { invoke("data:harden") }

    assert_includes out, "DRY-RUN"
    assert_includes out, "a•••@robotakas.test"
    assert_includes out, "d•••@robotakas.test"
    refute_includes out, "other@example.com"

    assert_equal "admin", @admin.reload.role
    assert @admin.authenticate("Admin1234!")
    assert @demo.reload.authenticate("Demo1234!")
    assert @other.reload.authenticate("Other1234!")
  end

  test "with CONFIRM=yes demotes the old admin and rotates demo passwords" do
    ENV["OLD_ADMIN_EMAIL"] = "admin@robotakas.test"
    ENV["DEMO_PASSWORD"] = "BrandNewDemoPass123"
    ENV["CONFIRM"] = "yes"

    out, _err = capture_io { invoke("data:harden") }

    assert_equal "user", @admin.reload.role
    refute @admin.authenticate("Admin1234!")
    assert @demo.reload.authenticate("BrandNewDemoPass123")
    assert @other.reload.authenticate("Other1234!")
    refute @other.authenticate("BrandNewDemoPass123")

    refute_includes out, "BrandNewDemoPass123"
  end

  test "without DEMO_PASSWORD the demo password step is skipped and reported" do
    ENV["OLD_ADMIN_EMAIL"] = "admin@robotakas.test"
    ENV["CONFIRM"] = "yes"

    out, _err = capture_io { invoke("data:harden") }

    assert_includes out, "DEMO_PASSWORD verilmedi"
    assert_equal "user", @admin.reload.role
    assert @demo.reload.authenticate("Demo1234!")
  end

  test "without OLD_ADMIN_EMAIL the admin step is skipped" do
    ENV["CONFIRM"] = "yes"

    out, _err = capture_io { invoke("data:harden") }

    assert_includes out, "OLD_ADMIN_EMAIL verilmedi"
    assert_equal "admin", @admin.reload.role
  end
end
