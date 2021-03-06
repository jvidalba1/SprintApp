#encoding: utf-8
ActiveAdmin.register AdminUser, :sort_order => "email_desc" do
  
  # for use with cancan
  controller.authorize_resource
  
  # Menu item
  menu :label => "Cuentas de usuario", :parent => "Administración", :if => proc { can?( :index, AdminUser) }
      
  # Conditionally show the "Change Password" action_item button, if the user has access to do that
  action_item :only => [:edit, :show] do
    if controller.current_ability.can?( :change_password, resource )
      link_to "Cambiar contraseña", change_password_admin_user_path( resource )
    end
  end
  
  action_item :only => [:edit, :show] do
    if controller.current_ability.can?( :change_password, resource )
      if resource.active?
        link_to "Desactivar", deactivate_admin_user_path(resource)
      else
        link_to "Activar", activate_admin_user_path(resource)
      end
    end
  end
    
  
  # Scope buttons on index listing
  scope :all
  scope :active, :default => true
  scope :inactive
  
  AdminUser::ROLES.each do |role|
   scope role.to_sym do |users|
     users.where :role => role
   end
  end
  

  # Index listing filters
  filter :team, :collection => proc { Team.all }
  filter :email
  filter :first_name
  filter :last_name
  filter :github
  filter :current_sign_in_at
  filter :last_sign_in_at
  filter :created_at
  filter :updated_at
  
  batch_action :deactivate, { if: proc{ can? :deactivate, AdminUser }, confirm: '¿Esta seguro que quieres desactivar esos usuarios? Esto evitará que inicien sesión' } do |selected_ids|
    AdminUser.find(selected_ids).each { |u| u.suspend! }
    redirect_to collection_path, notice: "#{selected_ids.count} usuarios desactivados exitosamente."
  end
  
  batch_action :activate, { if: proc { can? :activate, AdminUser } , confirm: '¿Esta seguro que quieres activar esos usuarios? Esto les permitirá iniciar sensión' } do |selected_ids|
    AdminUser.find(selected_ids).each { |u| u.unsuspend! }
    redirect_to collection_path, notice: "#{selected_ids.count} usuarios activados exitosamente."
  end

  batch_action :destroy, { if: proc{ can? :destroy, AdminUser }, priority: 100, confirm: I18n.t('active_admin.batch_actions.delete_confirmation', plural_model: "users") } do |selected_ids|
    AdminUser.destroy_all id: selected_ids
    redirect_to collection_path, :notice => I18n.t("active_admin.batch_actions.succesfully_destroyed", count: selected_ids.count, model: "user", plural_model: "users")
  end
  
  # Index listing
  index do
    selectable_column
    column(:first, sortable: :first_name) { |user| link_to user.first_name, user }
    column(:last, sortable: :last_name) { |user| link_to user.last_name, user }
	  column(:email, sortable: :email) { |user| link_to user.email, user }
    column "Último inicio", :sortable => :last_sign_in_at do |user|
      user.last_sign_in_at.blank? ? raw( '<span class="empty">None</span' ) : user.last_sign_in_at.humanize
    end
    column "Creado", :sortable => :created_at do |user|
     user.created_at.humanize
    end
    column "Acciones" do |user|
      actions = ""
      actions += link_to( "Ver", resource_path(user), :class => "member_link" ) if can?( :read, user )
      actions += link_to( "Editar", edit_resource_path(user), :class => "member_link" ) if can?( :edit, user )
      actions += link_to( "Cambiar contraseña", change_password_admin_user_path( user ), :class => "member_link" ) if can?( :change_password, user )
      actions += link_to( "Borrar", resource_path(user), :method => :delete, :confirm => "¿Esta seguro?", :class => "member_link" ) if can?( :destroy, user )
      actions.html_safe
    end
  end
  
  
  # Create/Edit Form
  form :partial => "form"
  
  
  # Show View
  show :title => proc { "Usuario: " + resource.full_name } do
    panel "Información de usuario" do
      attributes_table_for resource do
        row "Nombres" do
          resource.first_name
        end
        row "Apellidos" do
          resource.last_name
        end
        row :email
        row "Zona horaria" do
          resource.time_zone
        end
        row(:github) { github_link resource }
        row "Rol" do
          resource.role.titleize
        end
        row "Equipos" do
          raw(resource.teams.collect { |team| link_to team.name, team }.join(", "))
        end
      end
    end
    panel "Proyectos" do
      attributes_table_for resource do
        row "Miembro" do
          ul do 
            resource.projects.each do |project|
              li link_to(project.name, project)
            end
          end
        end
      end
    end
  end
  
  sidebar "Perfil e información de inicio de sesión", only: [:show, :edit] do
    attributes_table_for resource do
      row(:avatar) do
        text_node avatar(resource)
        div class: :cleared
      end
      row "Actualmente registrado a" do
        link_to truncate(resource.ticket_timer.ticket.long_name, length: 50), project_ticket_path(resource.ticket_timer.ticket.project, resource.ticket_timer.ticket), title: resource.ticket_timer.ticket.long_name if resource.ticket_timer.present?
      end
      row "Inicios de sesión" do
        resource.sign_in_count
      end
      row "Actual IP de inicio de sesión" do
        resource.current_sign_in_ip
      end
      row "Última IP de inicio de sesión" do
        resource.last_sign_in_ip
      end
      row "Creado" do
        resource.created_at.humanize
      end
      row "Actualizado" do
        resource.updated_at.humanize
      end
    end    
  end
  
  sidebar "Estadísticas de usuario", only: [:show, :edit] do
    text_node( render "shared/user_statistics", user: resource )    
  end
  
  member_action :change_password do
    @user = AdminUser.find( params[:id] ) rescue current_admin_user
  end
  
  member_action :deactivate do
    @user = AdminUser.find(params[:id]) rescue nil
    unless @user.nil?
      @user.suspend!
      redirect_to( {:action => :index}, :alert => "La cuenta fue suspendida" )
    end
  end
  
  member_action :activate do
    @user = AdminUser.find(params[:id]) rescue nil
    unless @user.nil?
      @user.unsuspend!
      redirect_to( {:action => :index}, :alert => "La cuenta fue activada" )
    end
  end
  
  collection_action :profile do
    redirect_to edit_admin_user_path( current_admin_user )
  end
  
  member_action :process_password_change, method: :put do    
    @user = AdminUser.find(params[:id]) rescue nil
    unless @user.nil?
      @user.update_attributes params[:admin_user]
      if @user.save
        redirect_to admin_users_path, :notice => "Contraseña cambiada exitosamente"
      else
        flash.now[:alert] = "Error cambiando contraseña"
        render "change_password"
      end
    end
  end
    
end
