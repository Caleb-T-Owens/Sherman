class PostsController < ApplicationController
  before_action :set_post, only: %i[ like unlike ]

  def new
    @post = Post.new
  end

  def create
    @post = Current.user.posts.build(post_params)

    if @post.save
      redirect_to root_path, notice: "Post was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def like
    @like = Current.user.likes.build(post: @post)

    if @like.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back(fallback_location: root_path) }
      end
    else
      redirect_back(fallback_location: root_path, alert: "Could not like post")
    end
  end

  def unlike
    @like = Current.user.likes.find_by!(post: @post)

    if @like.destroy
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back(fallback_location: root_path) }
      end
    else
      redirect_back(fallback_location: root_path, alert: "Could not unlike post")
    end
  end

  private

  def post_params
    params.require(:post).permit(:content)
  end

  def set_post
    @post = Post.find(params[:id])
  end
end 