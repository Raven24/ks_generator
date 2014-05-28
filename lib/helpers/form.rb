
module Helpers::Form
  def checkbox(name, text, checked=false, fmt=:haml)
    output = <<-END
%input{type: :hidden, name: '#{name}', value: 0 }
%label
  %input{type: :checkbox, name: '#{name}', value: 1, checked: #{(checked ? 'true' : 'false')} }
  #{text}
    END

    return output if fmt==:raw
    haml output
  end

  def check_group(text, options)
    check_options = options.map do |entry|
      checkbox(entry[:name], entry[:text], entry[:checked], :raw)
    end.join("\n")

    haml <<-END
%div.group_header
  #{text}

%div.columns
  #{check_options.split("\n").join("\n  ")}
    END
  end

  def radio_group(name, text, options)
    radio_options = options.map do |entry|
      <<-END
%label
  %input{type: :radio, name: '#{name}', value: '#{entry[:value]}', checked: #{(entry[:checked] ? 'true' : 'false')} }
  #{entry[:text]}
      END
    end.join("\n")

    haml <<-END
%div.group_header
  #{text}
#{radio_options}
    END
  end

  def dropdown(name, text, options)
    select_options = options.map do |entry|
      <<-END
    %option{value: '#{entry[:value]}', selected: #{entry[:selected] ? 'true' : 'false'} }
      #{entry[:text]}
      END
    end.join("\n")

    haml <<-END
%label
  #{text}
  %select{name: '#{name}'}
#{select_options}
    END
  end
end
