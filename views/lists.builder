xml.div(:class => 'block') {
  xml.h2 I18n.t("lists")
  xml.form(:action => "/subscribe", :method => 'post') {
    xml.ul {
      @ml.lists.each do |list|
        xml.li {
          xml.input(:type => 'checkbox',
                    :name => "list_#{list.name}",
                    :id => list.name,
                    :value => list.name)
          xml.label(:for => list.name) {
            xml.span("#{list.name}@#{list.domain}",
                     :class => 'email')
          }
          nb = list.members.length
          name = nb <= 1 ? "membre" : "membres"
          xml.span("#{nb} #{name}", :class => 'info')
          xml.span(:class => 'buttons') {
            xml.a(I18n.t("post"),
                  :class => 'button',
                  :href => "mailto:#{list.name}@#{list.domain}")
            xml.a(I18n.t("archives"),
                  :class => 'button',
                  :href => "/#{list.name}/") if !List.empty?(list.name)
          }
        }
      end
    }
    xml << builder(:subscribe)
  }
}
