module AdminContentHelper

  def content_for(priv,&blk)
    #c = @gAdmin
    c = controller.current_admin
    p = "is_#{priv}"
    yield blk if c.respond_to?(p) && c.send(p)
  end

  def content_for_boxoffice(&blk) ; content_for(:boxoffice, blk) ; end
  def content_for_boxoffice_manager(&blk) ; content_for(:boxoffice_manager, blk) ; end
  def content_for_staff(&blk) ; content_for(:staff, blk) ; end
  def content_for_admin(&blk) ; content_for(:admin, blk) ; end

end
    
      
