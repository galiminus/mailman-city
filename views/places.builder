xml.div(:class => 'block') {
  xml.h2 "Villes"
  xml.ul {
    @places.each do |place|
      xml.li {
        xml.a place.name.capitalize, :href => "/#{place.name}"
        nb = place.lists.length
        name = nb <= 1 ? "list" : "lists"
        xml.span("#{nb} #{name}", :class => 'info')
      }
    end
  }
}
