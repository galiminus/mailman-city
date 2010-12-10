if @subscribe != nil
  xml.div(:id => 'subform') {
    xml.span(I18n.t("confirm_email"))
    xml.span(@email, :class => 'email')
  }
else
  xml.div(:id => 'subform') {
    xml.label(I18n.t("email_addr"), :for => 'email')
    xml.input(:type => 'text',
              :name => 'email',
              :value => @email,
              :id => 'email')
    xml.input(:type => 'submit',
              :name => 'subscribe',
              :value => I18n.t("unsub"))
    xml.input(:type => 'submit',
              :name => 'subscribe',
              :value => I18n.t("sub"))
  }
end
