xml.instruct!
xml.declare! :DOCTYPE, :html, :PUBLIC, "-//W3C//DTD XHTML 1.0 Strict//EN", "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
xml.html(:xmlns => "http://www.w3.org/1999/xhtml") {
  xml.head {
    xml.title $title
    xml.link(:type => 'text/css', :href => '/css/base.css', :rel => 'stylesheet')
  }
  xml.body {
    xml.div(:id => 'header') {
      xml.div(:id => 'title') {
        xml.h1 $title
      }
    }
    xml.div(:id => 'nav') {
      xml.ul {
        xml.li(:class => 'left') {
          xml.a("Home",
                :href => '/',
                :class => (@page == 'home' ? 'on' : 'off'))
        }
        xml.li("/", :class => 'left sep')

        if @place
          xml.li(:class => 'left') {
            xml.a(@place.name.capitalize,
                  :href => "/#{@place.name}",
                  :class => (@page == 'place' ? 'on' : 'off'))
          }
          xml.li("/", :class => 'left sep')
        end
        
        if @list
          xml.li(:class => 'left') {
            xml.a(@list.name,
                  :href => "/#{@place.name}/#{@list.name}/",
                  :class => (@page == 'list' ? 'on' : 'off'))
          }
          xml.li("/", :class => 'left sep')
        end


        if @date
          xml.li(:class => 'left') {
            xml.a(@date.sub(/([0-9]+)-(.+)/, '\2 \1'),
                  :href => "/#{@place.name}/#{@list.name}/#{@date}/thread.html",
                  :class => (@page == 'date' ? 'on' : 'off'))
          }
        end

        xml.li(:class => 'right') {
          xml.a I18n.t("contact"),
          :href => "mailto:#{$contact}",
          :class => 'off'
        }
      }
    }
    xml.div(:id => 'content') {
      xml << yield
    }
  }
}
