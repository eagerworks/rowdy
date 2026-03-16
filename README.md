# Rowdy

Rowdy is a Rails engine for asynchronous file upload and XLSX import, column mapping, validation, and real-time status updates via Turbo Streams.

## Requirements

- Ruby >= 3.2
- Rails >= 8.0
- PostgreSQL or MySQL
- A background job adapter (Sidekiq, Solid Queue, GoodJob, etc.)
- An Action Cable adapter that works across processes (`solid_cable`, Redis, etc.)

## Installation

Add to your `Gemfile`:

```ruby
gem "rowdy"
```

## Setup

### 1. Run the install generator

```bash
rails generate rowdy:install
```

The generator will automatically:

- Create `config/initializers/rowdy.rb` with a starter configuration
- Mount the engine in `config/routes.rb`
- Inject the Rowdy stylesheet into `app/views/layouts/application.html.erb`
- Inject the JS imports into `app/javascript/application.js`
- Copy Active Storage and Rowdy migrations
- Warn if Action Cable is using the `async` adapter (not compatible with Rowdy)

### 2. Run migrations

```bash
rails db:migrate
```

### 3. Configure background jobs

Rowdy uses ActiveJob and works with any queue adapter. Make sure your adapter is configured to process the following queues:

- `rowdy_imports`
- `rowdy_processing`

### 4. Configure Action Cable

Rowdy requires an Action Cable adapter that works across processes (broadcasts originate from background jobs). The `async` adapter will **not** work.

Rowdy broadcasts to the following streams:

| Stream | Purpose |
|---|---|
| `rowdy_uploads_<schema_name>` | Upload list updates (new items, status changes) |

### 5. Configure Rowdy

Edit `config/initializers/rowdy.rb` (created by the generator):

```ruby
Rails.application.config.to_prepare do
  Rowdy.configure do |config|
    # Required: define how uploaded files are processed.
    # Call progress.call(percent) to report progress (0..100).
    config.processor = lambda do |input_path, upload, &progress|
      # process the file here...
      progress.call(100)
      input_path
    end

    # Optional: register import schemas (see Schemas section below)
    config.schemas = []
  end
end
```

#### Available configuration options

| Option | Default | Description |
|---|---|---|
| `processor` | passthrough lambda | Lambda that processes uploaded files |
| `schemas` | `[]` | List of import schema classes |
| `default_chunk_size` | `5 MB` | Size of each upload chunk |
| `max_file_size` | `500 MB` | Maximum allowed file size |
| `chunks_storage_path` | `tmp/rowdy_chunks` | Where chunks are stored temporarily |
| `orphan_cleanup_hours` | `24` | Hours before incomplete uploads are cleaned up |
| `import_batch_size` | `1000` | Rows processed per batch during import |
| `progress_broadcast_interval` | `5000` | Milliseconds between progress broadcasts |
| `import_queue` | `"rowdy_imports"` | Queue name for import jobs |

## Schemas

Schemas define the expected structure of imported files (XLSX). Each schema extends `Rowdy::Schema` and declares its columns with optional validations.

Place the schema class in `app/models/` (or any autoloaded path):

```ruby
# app/models/product_import_schema.rb
class ProductImportSchema < Rowdy::Schema
  column :name,     type: :string,  required: true,  max_length: 100
  column :sku,      type: :string,  required: true,  unique: true
  column :price,    type: :decimal, required: true,  greater_than: 0
  column :stock,    type: :integer, required: false
  column :category, type: :string,  required: false, inclusion: %w[electronics clothing food other]
end
```

Then register it in `config/initializers/rowdy.rb`:

```ruby
config.schemas = [ProductImportSchema]
```

### Supported column types

- `:string`
- `:integer`
- `:decimal`

### Supported column validations

| Option | Description |
|---|---|
| `required: true` | Column must be present |
| `unique: true` | Values must be unique within the file |
| `max_length: N` | Maximum string length |
| `greater_than: N` | Numeric value must exceed N |
| `inclusion: [...]` | Value must be in the given list |

## Usage

Render the main upload and import component in any view:

```erb
<%= render Rowdy::SchemasComponent.new %>
```

This renders the full dropzone, upload list, and import flow.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
