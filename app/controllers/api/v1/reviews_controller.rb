class Api::V1::ReviewsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:show, :create, :update]

  def index
    render json: Review.all
  end

  def show
    render json: Beer.find(params[:id]).reviews
  end

  def create
    review = Review.new(review_params)
    beer = Beer.find(review_params['beer_id'])
    review.user = current_user
    if review.save
      flash[:notice] = "Beer review added successfully"
      review_to_send = {}
      review_to_send[:id] = review.id
      review_to_send[:body] = review.body
      review_to_send[:rating] = review.rating
      review_to_send[:votes] = []
      review_to_send[:created_at] = review.created_at
      render json: {
       status: 201,
       message: ("successfully created a review"),
       review: review_to_send
      }.to_json
    else
      flash[:notice] = "Review failed to save"
      render json: {
        status: 400,
        error: review.errors
      }.to_json, status: :bad_request
    end
  end

  def update
    review = Review.find(update_params['id'])
    @beer_id = review.beer.id
    updown = review.updowns.find_by(user: current_user)
    if !updown
      new_vote = Updown.new(
        review: review,
        user: current_user,
        vote: update_params['vote']
      )

      if new_vote.valid?
        new_vote.save
        render json: {
          status: 201,
          message: "You voted on a beer review!",
          reviews: updated_reviews
        }.to_json
      else
        render json: {
          status: 500,
          error: new_vote.errors.full_messages
        }.to_json, status: :bad_request
      end
    elsif updown.update!(vote: update_params['vote'])
      render json: {
        status: 201,
        message: "you updated your vote!",
        reviews: updated_reviews
      }.to_json
    else
      render json: {
        status: 500,
        error: updown.errors
      }.to_json, status: :bad_request
    end
  end

  private

  def review_params
    params.require(:review).permit(:body, :rating, :beer_id)
  end

  def update_params
    params.require(:updown).permit(:id, :vote)
  end

  def updated_reviews
    reviews = []
    Review.where(beer_id: @beer_id).each do |review|
      review_to_send = {}
      review_to_send[:id] = review.id
      review_to_send[:body] = review.body
      review_to_send[:rating] = review.rating

      updowns = []
      review.updowns.each do |updown|
        thing = {}
        thing[:votes] = updown.vote
        thing[:reviewer] = updown.user_id
        updowns << thing
      end
      review_to_send[:votes] = updowns
      review_to_send[:created_at] = review.created_at
      reviews << review_to_send
    end
    reviews
  end
end
