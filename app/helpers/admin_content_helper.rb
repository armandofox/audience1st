module AdminContentHelper
  include AuthenticatedSystem
  
  def privileged_content_for(priv,&blk)
    return unless @gAdminDisplay
    c = current_user
    p = "is_#{priv}"
    yield blk if c.respond_to?(p) && c.send(p)
  end

  def privileged_content_for_boxoffice(&blk) ; privileged_content_for(:boxoffice, blk) ; end
  def privileged_content_for_boxoffice_manager(&blk) ; privileged_content_for(:boxoffice_manager, blk) ; end
  def privileged_content_for_staff(&blk) ; privileged_content_for(:staff, blk) ; end
  def privileged_content_for_admin(&blk) ; privileged_content_for(:admin, blk) ; end

end
    
      
