xml.div(:class => 'block') {
  title = @subscribe ? "Inscription confirmee" : "Desinscription confirmee"
  xml.h2 title
  xml.ul {
    @lists.each do |list|
      xml.li("#{list.name}@#{list.host}",
             :class => 'email')
    end
  }
}
