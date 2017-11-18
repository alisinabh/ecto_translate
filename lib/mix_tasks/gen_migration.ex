defmodule Mix.Tasks.EctoTranslate.Gen.Migration do
  use Mix.Task

  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator
  import Mix.Ecto

   @shortdoc "Generates a new migration for the EctoTranslate translation table"

  def run(args) do
    # no_umbrella!("ecto.gen.migration")
    repos = parse_repo(args)
    name = "ecto_translate"

    Enum.each repos, fn repo ->
          ensure_repo(repo, args)
          path = migrations_path(repo)
          file = Path.join(path, "#{timestamp()}_#{underscore(name)}.exs")
          create_directory path

          assigns = [mod: Module.concat([repo, Migrations, camelize(name)]),
                     change: change()]
          create_file file, migration_template(assigns)

          if open?(file) and Mix.shell.yes?("Do you want to run this migration?") do
            Mix.Task.run "ecto.migrate", [repo]
          end
    end
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)

  defp change do
    """
        create table(:test_model) do
          add :title, :string
          add :description, :string
        end


        create table(:translations) do
          add :translatable_id, #{EctoTranslate.translatable_id_type()}
          add :translatable_type, :string
          add :locale, :string
          add :field, :string
          add :content, :text

          timestamps
        end
        create index :translations, [:translatable_id, :translatable_type]
        create index :translations, [:translatable_id, :translatable_type, :locale]
        create unique_index(:translations, [:translatable_id, :translatable_type, :locale, :field])
    """
  end

  embed_template :migration, """
  defmodule <%= inspect @mod %> do
    use Ecto.Migration
    def change do
  <%= @change %>
    end
  end
  """
end
