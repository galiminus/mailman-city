xml.div(:class => 'block') {
  title = @subscribe ? I18n.t("confirmed_sub") : I18n.t("confirmed_unsub")
  xml.h2 title
  xml.ul {
    @lists.each do |list|
      xml.li("#{list.name}@#{list.domain}", :class => 'email')
    end
  }
}
