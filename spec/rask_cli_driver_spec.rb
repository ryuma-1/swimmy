require "open3"
require "json"

RSpec.describe Swimmy::Service::RaskCliDriver do
  let(:driver) { Swimmy::Service::RaskCliDriver }
  let(:success_status) { instance_double(Process::Status, success?: true) }
  let(:failure_status) { instance_double(Process::Status, success?: false) }

  before do
    ENV["RASK_CLI_DIR"] = "/path/to/rask/cli"
    driver.instance_variable_set(:@cli_dir, nil)
  end

  def stub_capture3(*expected_args, stdout:)
    expect(Open3).to receive(:capture3)
      .with("/path/to/rask/cli/target/debug/rask-cli", *expected_args, chdir: "/path/to/rask/cli")
      .and_return([stdout, "", success_status])
  end

  describe ".task_create" do
    it "requires only title and assigner_name" do
      stub_capture3(
        "task", "create", "--title", "buy milk", "--assigner-name", "john",
        stdout: "Success to add new task"
      )

      driver.task_create(title: "buy milk", assigner_name: "john")
    end

    it "includes all optional flags when given" do
      stub_capture3(
        "task", "create",
        "--title", "buy milk", "--assigner-name", "john",
        "--state", "done",
        "--project-name", "shopping",
        "--due-at", "2036-2-6",
        "--description", "2% milk",
        stdout: "Success to add new task"
      )

      driver.task_create(
        title: "buy milk",
        assigner_name: "john",
        state: "done",
        project_name: "shopping",
        due_at: "2036-2-6",
        description: "2% milk"
      )
    end
  end

  describe ".task_list" do
    let(:task_json) do
      JSON.generate([{
        "id" => 1, "content" => "buy milk", "state" => 1, "description" => nil,
        "due_at" => nil, "created_at" => "2036-01-01T00:00:00Z", "updated_at" => "2036-01-01T00:00:00Z",
        "creator" => { "id" => 10, "name" => "john" },
        "assigner" => { "id" => 10, "name" => "john" },
        "project" => nil, "url" => "https://rask.example.com/tasks/1.json"
      }])
    end

    it "requests --json always and returns parsed Task objects" do
      stub_capture3("task", "list", "--json", stdout: task_json)

      tasks = driver.task_list

      expect(tasks.length).to eq(1)
      expect(tasks.first).to be_a(Swimmy::Resource::Task)
      expect(tasks.first.content).to eq("buy milk")
      expect(tasks.first.creator.name).to eq("john")
    end

    it "filters by username" do
      stub_capture3("task", "list", "--json", "--username", "john", stdout: task_json)

      driver.task_list("john")
    end
  end

  describe ".document_list" do
    let(:document_json) do
      JSON.generate([{
        "id" => 2123, "content" => "議事録", "creator" => { "id" => 5, "name" => "john" },
        "description" => "desc", "created_at" => "2036-01-01T00:00:00Z", "updated_at" => "2036-01-01T00:00:00Z",
        "project" => nil, "start_at" => nil, "end_at" => nil, "location" => nil,
        "url" => "https://rask.example.com/documents/2123.json"
      }])
    end

    it "requests --json always and returns parsed Document objects" do
      stub_capture3("document", "list", "--json", stdout: document_json)

      documents = driver.document_list

      expect(documents.length).to eq(1)
      expect(documents.first).to be_a(Swimmy::Resource::Document)
      expect(documents.first.id).to eq(2123)
      expect(documents.first.description).to eq("desc")
    end

    it "expands array filters into repeated values" do
      stub_capture3(
        "document", "list", "--json",
        "--content", "rust", "api",
        "--creator-name", "john",
        stdout: document_json
      )

      driver.document_list(content: ["rust", "api"], creator_name: "john")
    end

    it "stringifies numeric filters" do
      stub_capture3("document", "list", "--json", "--id", "42", "--project-id", "7", stdout: document_json)

      driver.document_list(id: 42, project_id: 7)
    end
  end

  describe ".user_list" do
    it "returns parsed User objects" do
      user_json = JSON.generate([{
        "id" => 1, "name" => "john", "screen_name" => "john_s", "active" => true,
        "created_at" => "2036-01-01T00:00:00Z", "updated_at" => "2036-01-01T00:00:00Z",
        "url" => "https://rask.example.com/users/1.json"
      }])
      stub_capture3("user", "list", "--json", stdout: user_json)

      users = driver.user_list

      expect(users.first).to be_a(Swimmy::Resource::User)
      expect(users.first.screen_name).to eq("john_s")
    end
  end

  describe ".project_list" do
    it "returns parsed Project objects" do
      project_json = JSON.generate([{
        "id" => 3, "name" => "my project", "created_at" => "2036-01-01T00:00:00Z",
        "updated_at" => "2036-01-01T00:00:00Z", "user" => { "id" => 1, "name" => "john" },
        "url" => "https://rask.example.com/projects/3.json"
      }])
      stub_capture3("project", "list", "--json", stdout: project_json)

      projects = driver.project_list

      expect(projects.first).to be_a(Swimmy::Resource::Project)
      expect(projects.first.user.name).to eq("john")
    end
  end

  describe "error handling" do
    it "raises CommandFailedError when the CLI exits with failure" do
      allow(Open3).to receive(:capture3)
        .and_return(["", "boom", failure_status])

      expect { driver.task_list }.to raise_error(
        Swimmy::Service::RaskCliDriver::CommandFailedError, /boom/
      )
    end

    it "raises when RASK_CLI_DIR is not set" do
      ENV.delete("RASK_CLI_DIR")

      expect { driver.task_list }.to raise_error(/RASK_CLI_DIR/)
    end
  end
end
