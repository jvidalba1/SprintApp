#encoding: utf-8
ActiveAdmin.register Contact, :sort_order => "name_asc" do
  
  # for use with cancan
  controller.authorize_resource
  
  belongs_to :client, finder: :find_by_url!
  
  filter :name, :label => "Nombre"
  filter :email, :label => "Email"
  filter :phone, :label => "Teléfono"
  filter :created_at, :label => "Creado"
  filter :updated_at, :label => "Actualizado"
  
  index do |t|
    selectable_column
    column("Nombre") do
      resource.name
    end
    column :email, :sortable => :email do |contact|
      link_to contact.email, "mailto:#{contact.email}"
    end
    column("Teléfono", sortable: :phone) { |contact| number_to_phone contact.phone }
    column("Celular", sortable: :cell, :label => "Celular") { |contact| number_to_phone contact.cell }
    column "Creado", :sortable => :created_at do |client|
      client.created_at.humanize
    end
    restricted_actions_column(t)
  end
  
  show :title => :name do
    
    panel "Detalle de contacto" do
      attributes_table_for resource do
        row "Nombre" do
          resource.name
        end
        row("Teléfono") { number_to_phone resource.phone }
        row("Celular") { number_to_phone resource.cell }
        row :email
        row "Creado" do
          resource.created_at.humanize
        end
        row "Actualizado" do
          resource.updated_at.humanize
        end
      end
    end
    
    text_node(render :partial => "addresses/show", :locals => { :address => resource.address })
    
  end
  
  form :partial => "form"
  
end
