if @subscribe != nil
  xml.div(:id => 'subform') {
    xml.span("Un email de confirmation vous a ete envoye a: ")
    xml.span(@email, :class => 'email')
  }
else
  xml.div(:id => 'subform') {
    xml.label("Email address:", :for => 'email')
    xml.input(:type => 'text',
              :name => 'email',
              :value => @email,
              :id => 'email')
    xml.input(:type => 'submit',
              :name => 'subscribe',
              :value => 'DÃsinscription')
    xml.input(:type => 'submit',
              :name => 'subscribe',
              :value => 'Inscription')
  }
end
