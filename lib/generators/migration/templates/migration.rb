class <%= migration_class_name %> < ActiveRecord::Migration
<%- up_body = migration.up_body('    ') -%>
<%- down_body = migration.down_body('    ') -%>
<%- if up_body -%>
  def up
<%= up_body -%>
  end
<%- end -%>
<%= "\n" if up_body && down_body -%>
<%- if down_body -%>
  def down
<%= down_body -%>
  end
<%- end -%>
end
