#encoding: utf-8
ActiveAdmin.register Client, :label => "Cliente", :sort_order => "name_asc" do
  
  # for use with cancan
  controller.authorize_resource
  controller.resources_configuration[:self][:finder] = :find_by_url!

  menu :label => "Clientes", :parent => "Administración", :if => proc { can?( :manage, Client) }

  filter :name, :label => "Nombre"
  filter :created_at, :label => "Creado"
  filter :updated_at, :label => "Actualizado"
  index :title => 'Your_page_name'
  action_item :only => [:show] do
    link_to "Contactos", client_contacts_path( resource )
  end
  
  index :title => "Clientes" do

    selectable_column
    column("Nombre", sortable: :name) { |client| link_to truncate(client.name, length: 35), client, title: client.name }
    column "Creado", :sortable => :created_at do |client|
      client.created_at.humanize
    end
    column "Actualizado", :sortable => :updated_at do |client|
      client.updated_at.humanize
    end
    column "Opciones" do |client|
      restricted_default_actions_for_resource(client) + link_to( "Contactos", client_contacts_path(client), :class => "member_link" )
    end
  end
  
  form :partial => "form"
  
  show :title => "Clientes" do
    
    panel "Detalle de cliente" do
      attributes_table_for resource do
        row "Nombre" do
          resource.name
        end
        row "Tasa por hora" do
          resource.hourly_rate { number_to_currency resource.hourly_rate }
        end
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

end
