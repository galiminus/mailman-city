xml.div(:class => 'block') {
  xml.h2 @place.name.capitalize
  xml.form(:action => "/#{@place.name}/subscribe", :method => 'post') {
    xml.ul {
      @place.lists.each do |list|
        xml.li {
          xml.input(:type => 'checkbox',
                    :name => "list_#{list.name}",
                    :id => list.name,
                    :value => list.name)
          xml.label(:for => list.name) {
            xml.span("#{list.name}@#{list.host}",
                     :class => 'email')
          }
          nb = list.members.length
          name = nb <= 1 ? "membre" : "membres"
          xml.span("#{nb} #{name}", :class => 'info')
          xml.span(:class => 'buttons') {
            xml.a(I18n.t("post"),
                  :class => 'button',
                  :href => "mailto:#{list.name}@#{list.host}")
            xml.a(I18n.t("archives"),
                  :class => 'button',
                  :href => "/#{@place.name}/#{list.name}/") if !List.empty?(@place.name, @list.name)
          }
        }
      end
    }
    xml << builder(:subscribe)
  }
}
