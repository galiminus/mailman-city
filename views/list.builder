xml.div(:class => 'block') {
  xml.h2("#{@list.name}@#{@list.host}")
  xml << @archive
}
