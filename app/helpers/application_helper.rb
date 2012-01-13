module ApplicationHelper

  # The traditional "3 days ago" result isn't good enough. Examples of when you might like to know a commit happened:
  # 10 minutes ago
  # 10:15am
  # 1 hour ago (4:15pm)
  # Monday, 4:10pm
  # Last Monday (Dec 3rd), 4:10pm
  # Dec 24th, 2010

  # TODO: currently appearing in UTC, that's no good.
  def as_commit_time(commit_time)
    return if commit_time.nil?

    now = Time.now
    relative = (now - commit_time).to_i
    timetoday = commit_time.strftime('%l:%M%p').downcase.strip
    day = commit_time.strftime("%A").strip
    date = "#{commit_time.strftime("%b").strip} #{commit_time.strftime("%e").strip}"

    # TODO: This could be nicer around midnight, but not important.
    if now.day == commit_time.day
      case relative
      when 0..59 then "#{relative.to_s} seconds ago"
      when 60..3599 then "#{(relative/60).to_i} minutes ago"
      when 1.hours..2.hours then "an hour ago (#{timetoday})"
      when 2.hours..5.hours then "#{(relative/3600).to_i} hours ago (#{timetoday})"
      else "#{timetoday}"
      end
    elsif now.day == commit_time.day+1
      "Yesterday at #{timetoday}"
    elsif commit_time > 1.week.ago
      "#{day} at #{timetoday}"
    elsif 2.weeks.ago < commit_time && commit_time < 1.week.ago
      "Last #{day} (#{date}) at #{timetoday}"
    elsif now.year == commit_time.year
      "#{date} at #{timetoday}"
    else
      "#{date}, #{commit_time.year}"
    end
  end

  def as_length_of_build(start, stop)
    # TECHNICAL_DEBT: we should add stop_times for all builds, and then update the DB
    if stop == nil
      stop = Time.now
    end

    seconds = (stop - start).to_i
    minutes = (seconds / 60).to_i
    hours = (minutes / 60).to_i

    if hours > 0
      "#{hours}h #{minutes % 60}m"
    elsif minutes > 0
      "#{minutes}m #{seconds % 60}s"
    else
      "#{seconds}s"
    end
  end

  def revision_link(url, revision)
    return if url.nil? or revision.nil?

    # TECHNICAL_DEBT: github only
    link_to(revision[0..8], url + "/commit/" + revision)
  end

  def bootstrap_status(build)
    type = case build.status
           when :fail
             :important
           when :killed
             :warning
           when :success
             :success
           when :running
             :notice
             end
    "<span class='label #{type}'>#{ build.status }"
  end


  def as_action_timestamp(time)
    time.strftime("%T.%3N")
  end

  def trigger_project_button(project, options={})
    name = options[:name] || "Trigger build"
    flash = options[:flash] || "Submitting..."
    twitter_bootstrap_form_for [project, Build.new], :remote => true do |f|
      f.submit name, :disable_with => flash
    end
  end

  def project_link_to(project)
    return unless project
    link_to project.github_project_name, github_project_path(project)
  end


  # TECHNICAL_DEBT: these shouldn't even exist, never mind being two separate functions.
  def build_link_to(build, project=nil)
    return if build.nil? || build.build_num.nil?

    project = project || build.the_project
    begin
      link = github_project_path(project) + "/" + build.build_num.to_s
    rescue
      return "" # new projects may have no builds available yet
    end

    # TECHNICAL_DEBT: kill this function - this puts the word build where it shouldnt be.
    link_to build.build_num.to_s, build_path(:project => build.project, :id => build.build_num)
  end


  def build_absolute_link_to(build, options={})
    project = build.the_project
    begin
      text = options[:text] || build.build_num.to_s
      anchor = github_project_path(project) + "/" + build.build_num.to_s
    rescue
      return "" # new projects may have no builds available yet
    end

    link_to text, build_url(:project => project, :id => build.build_num.to_s)
  end
end
