#encoding: utf-8
ActiveAdmin.register TicketStatus, :sort_order => 'name_asc' do
  
  # for use with cancan
  controller.authorize_resource
  
  menu :parent => "Administración", :if => proc { can?( :manage, TicketStatus ) }
    
  filter :name, :label => "Nombre"
  filter :created_at, :label => "Creado"
  filter :updated_at, :label => "Actualizado"
  
  scope :all, :default => true
  scope(:open) { |statuses| statuses.active }
  scope(:closed) { |statuses| statuses.closed }
  
  index do |t|
    selectable_column
    column("Nombre", sortable: :name) { |item| link_to truncate(item.name, length: 35), item, title: item.name }
    column 'Estado: abierto', :sortable => :active do |status|
      status_tag status.active? ? "Activo" : "Cerrado", status.active? ? :green : :red
    end
    restricted_actions_column(t)
  end
  
  form :partial => "form"
  
  show :title => :name do
    panel "Detalle de estado" do
      attributes_table_for resource do
        row "Nombre" do
          resource.name
        end
      end
    end
  end
  
end
