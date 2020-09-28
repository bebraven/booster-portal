namespace :data do
  namespace :export do

    def export_download(course_id)
      admin = User.find 1
      puts("### Exporting data for Course #{course_id} - #{Time.now.strftime("%Y-%m-%d %H:%M:%S %Z")}")
      Export::GradeDownload.csv(admin, course_id: course_id)
    end

    desc 'Extract out the column names and generate the migration'
    task :generate_scores_migration, [:course_id] => :environment do |t, args|
      course_id = args[:course_id].to_i
      puts("Exporting download for Course #{course_id}")
      download = export_download(course_id)
      header = nil
      CSV.parse(download) { |r| header = r; break }

      puts """
class CreateProjectScores#{course_id}Table < ActiveRecord::Migration
  tag :predeploy
  def change
    orig_column_names = #{header}

    create_table :course#{course_id}_project_scores do |t|
      orig_column_names.each do |col_name|

        new_name = col_name.downcase.gsub(/[^0-9a-z]/, '_').to_sym
        if ['Student Name', 'Student Email'].member? col_name then
          t.string new_name
        else
          t.integer new_name
        end
      end
    end
  end
end
"""
    end


    desc 'Extract project component scores out into a separate table'
    task :project_scores, [:course_id] => :environment do |t, args|

      course_id = args[:course_id].to_i
      klass = "Course#{course_id}ProjectScore".constantize
      klass.column_names.delete('id')
      output = export_download(course_id)

      # we want to truncate and not just delete so that the ids start back at 1
      # the way Periscope syncing works means that old rows will get overwritten this
      # way so that we don't waste space
      ActiveRecord::Base.connection.execute("TRUNCATE #{klass.table_name}")
      puts("  Transferring to database table")
      header_row = true # skip the header
      CSV.parse(output) do |row|
        if header_row then
          header_row = false
          # Validate that the grade export format matches the table we created to hold it.
          # It can change if we add new assignments, add or delete rubric rows, or edit rubric criteria
          # Also, the order of the columns matters.
          # See, for example, db/migrate/20191016032556_replace_project_scores73_table.rb for how the
          # table column names where created.
          if row.length != klass.column_names.length then
            raise RuntimeError.new("The number of columns in Export::GradeDownload (#{row.length}) doesn't match the number of columns in #{klass.name} (#{klass.column_names.length}).")
          end
          row.each_with_index do |parsed_colname, i| 
            # Don't do an exact match bc we may have had to deal with weird chars when creating the table.
            # Also, the table column name may be truncated (postgres has a max column name lenght)
            header_colname_stripped = parsed_colname.downcase.gsub(/[^0-9a-z]/, '')
            klass_colname_stripped = klass.column_names[i].downcase.gsub(/[^0-9a-z]/, '')
            unless klass_colname_stripped.start_with? header_colname_stripped[0..klass_colname_stripped.length-1]
              err_msg = "The Export::GradeDownload.csv headers no longer match the #{klass.name} columns. Mismatch for: database column = #{klass.column_names[i]}, column in .csv export = #{parsed_colname}"
              raise RuntimeError.new(err_msg)
            end
          end
        else
          # This fails silently if there are mismatches. It just puts the first X values in regardless
          # of whether the order changed or there is more. Hence the validation of the header row before we start
          vals_by_colname = Hash[klass.column_names.zip row] 
          klass.create!(vals_by_colname)
        end
      end
      puts("  Done transferring to database table - #{Time.now.strftime("%Y-%m-%d %H:%M:%S %Z")}")
    end
  end
end
