#!/usr/bin/env ruby
# frozen_string_literal: true

require "attio"
require "json"

# Example: Advanced Filtering and Querying
#
# This example demonstrates how to use advanced filtering and sorting
# capabilities when querying records in Attio.

# Initialize the client
client = Attio.client(api_key: ENV.fetch("ATTIO_API_KEY"))

puts "Attio Advanced Filtering Example"
puts "=" * 40

# 1. Query with simple filters
puts "\n1. Finding people by email domain..."
people_from_domain = client.records.list(
  object: "people",
  filters: {
    email: { contains: "@example.com" },
  },
  limit: 10
)
puts "   Found #{people_from_domain.dig('data')&.length || 0} people from example.com"

# 2. Query with multiple filters (AND condition)
puts "\n2. Finding high-value companies in technology sector..."
high_value_tech = client.records.list(
  object: "companies",
  filters: {
    industry: { equals: "Technology" },
    annual_revenue: { greater_than: 1_000_000 },
  },
  sorts: [
    { field: "annual_revenue", direction: "desc" },
  ],
  limit: 5
)
puts "   Found #{high_value_tech.dig('data')&.length || 0} high-value tech companies"

# 3. Query with date range filters
puts "\n3. Finding recently created records..."
recent_date = (Date.today - 30).iso8601
recent_records = client.records.list(
  object: "people",
  filters: {
    created_at: { greater_than: recent_date },
  },
  sorts: [
    { field: "created_at", direction: "desc" },
  ]
)
puts "   Found #{recent_records.dig('data')&.length || 0} people created in last 30 days"

# 4. Query with relationship filters
puts "\n4. Finding people associated with specific companies..."
# First, get a company
companies = client.records.list(object: "companies", limit: 1)
if companies.dig("data", 0)
  company_id = companies.dig("data", 0, "id", "record_id")

  people_at_company = client.records.list(
    object: "people",
    filters: {
      company: {
        target_object: "companies",
        target_record_id: company_id,
      },
    }
  )
  puts "   Found #{people_at_company.dig('data')&.length || 0} people at the company"
else
  puts "   No companies found for demo"
end

# 5. Query with null/not null filters
puts "\n5. Finding records with missing data..."
missing_email = client.records.list(
  object: "people",
  filters: {
    email: { is_null: true },
  },
  limit: 10
)
puts "   Found #{missing_email.dig('data')&.length || 0} people without email addresses"

# 6. Complex sorting with multiple fields
puts "\n6. Sorting by multiple criteria..."
sorted_companies = client.records.list(
  object: "companies",
  sorts: [
    { field: "industry", direction: "asc" },
    { field: "annual_revenue", direction: "desc" },
    { field: "name", direction: "asc" },
  ],
  limit: 20
)
puts "   Retrieved #{sorted_companies.dig('data')&.length || 0} companies sorted by industry, revenue, and name"

# 7. Pagination example
puts "\n7. Paginating through results..."
page_size = 5
total_fetched = 0
cursor = nil

3.times do |page|
  params = {
    object: "people",
    limit: page_size,
  }
  params[:cursor] = cursor if cursor

  page_results = client.records.list(**params)
  fetched = page_results.dig("data")&.length || 0
  total_fetched += fetched

  puts "   Page #{page + 1}: fetched #{fetched} records"

  cursor = page_results.dig("pagination", "next_cursor")
  break unless cursor
end
puts "   Total fetched across pages: #{total_fetched}"

# 8. Query tasks with status filter
puts "\n8. Finding pending tasks..."
pending_tasks = client.tasks.list(
  status: "pending",
  limit: 10
)
puts "   Found #{pending_tasks.dig('data')&.length || 0} pending tasks"

# 9. Query with custom field filters
puts "\n9. Filtering by custom fields..."
# This assumes you have custom fields set up
client.records.list(
  object: "people",
  filters: {
    # Replace with your actual custom field API slug
    # custom_field: { equals: "some_value" }
  },
  limit: 10
)
puts "   Custom field filtering available for your specific schema"

# 10. Export query for analysis
puts "\n10. Exporting query results..."
export_data = client.records.list(
  object: "companies",
  filters: {
    industry: { not_null: true },
  },
  limit: 100
)

if export_data["data"] && !export_data["data"].empty?
  # Simple CSV-like export
  puts "   Sample export (first 3 records):"
  export_data["data"].take(3).each do |record|
    name = record.dig("values", "name", 0, "value") || "N/A"
    industry = record.dig("values", "industry", 0, "value") || "N/A"
    puts "   - #{name}: #{industry}"
  end
end

puts "\n" + ("=" * 40)
puts "Example completed successfully!"
puts "\nThis example demonstrated:"
puts "  • Simple and complex filtering"
puts "  • Multi-field sorting"
puts "  • Date range queries"
puts "  • Relationship filters"
puts "  • Null/not-null checks"
puts "  • Pagination"
puts "  • Task filtering"
puts "  • Custom field queries"
