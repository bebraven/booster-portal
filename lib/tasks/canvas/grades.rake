namespace :canvas do
  namespace :grades do
    desc 'Find module grades discrepancies when computer is greater than gradebook'
    task :audit_module , [:course_id, :module_item_id] => :environment do |t, args|

      course = Course.find args[:course_id]
      
      only_these = ["Lead Authentically","Tell Your Story", "Discover Your Career Path", "Network Like a Pro", "Apply for a Job", "Polish Your Portfolio", 
      "Ace your Interviews", "Capstone Kickoff", "Empathize", "Synthesize", "Ideate & Prototype", "Present Effectively", "Live Your Legacy"]
      
      module_item_id = ContentTag.where(id: course.sequential_module_item_ids, title: only_these).map(&:id)
      # => [7873, 7874, 7875, 7876, 7877, 7878, 7879, 7880, 7881, 7882, 7883, 7884, 7910]
      
      
      #module_item_id = args[:module_item_id]
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