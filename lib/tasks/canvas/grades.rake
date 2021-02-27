namespace :canvas do
  namespace :grades do
    desc 'Alter module grades if the calculated grade is higher'
    task :audit_course, [:course_id] => :environment do |t,args|
      course = Course.find args[:course_id]

      module_titles = [
       "Lead Authentically",
       "NLU Lead Authentically",
       "Tell Your Story", 
       "Discover Your Career Path", 
       "Network Like a Pro",
       "Apply for a Job",
       "Polish Your Portfolio",
       "Ace your Interviews",
       "Capstone Kickoff", 
       "Empathize", 
       "Synthesize", 
       "Ideate & Prototype", 
       "Present Effectively", 
       "Live Your Legacy" 
      ]

      module_item_ids = ContentTag.where(id: course.sequential_module_item_ids, 
                                         title: module_titles).
                                   map(&:id)
                                   
      bzg = BZGrading.new
      fudge = 0.001

      discrepancies = []
      module_item_ids.each do |module_item_id|
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
      end 
    end 
  end 
end
