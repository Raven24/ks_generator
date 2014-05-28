
module Helpers::Snippet
  def snippet_title
    session.delete(:fresh) ? "Congratulations, we're done." : "Your Kickstart Config"
  end

  def password_list(usrs)
    usrs.map { |u| "#{u[:name].ljust(10)}: #{u[:password]}" }.join("\n")
  end
end
