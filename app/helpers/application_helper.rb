module ApplicationHelper

 def logo
    image_tag("Text7.png", :alt => "Logo", :class => "round", :width => "65")
  end  

 def cover
    image_tag("Cover.jpeg", :alt => "Cover", :class => "round")
  end  

end
