namespace :canvas do
  namespace :grades do
    desc 'Find module grades discrepancies when computer is greater than gradebook'
    task :audit_module , [:course_id, :module_item_id] => :environment do |t, args|

      course = Course.find args[:course_id]
      module_item_id = args[:module_item_id]
      bzg = BZGrading.new
      fudge = 0.001

      discrepancies = []
      course.students.each do |student|
        cm = bzg.get_context_module(module_item_id)
        submission = bzg.get_participation_assignment(cm.course, cm).find_or_create_submission(student)
        next unless submission.try(:score)

        obj = bzg.calculate_user_module_score(module_item_id, student)
        score = obj['total_score']

        if score > (submission.score + fudge)
          discrepancy = {
            user_id: student.id,
            name: student.sortable_name,
            shown_grade: submission.score,
            calcuated: obj['total_score']
          }
          discrepancies << discrepancy
          bzg.set_user_grade_for_module(module_item_id, student, score)
        end

      end
      puts discrepancies
    end
  end
end