module ImageTransformations
  class Create
    include SolidUseCase

    steps :find_original_image,
          :find_existing_image_transformation,
          :create_image_transformation

    def find_original_image(params)
      p params
      params[:original_image] = Image.find_by(id: params[:id])
      return fail :not_found, error: 'NOT_FOUND' unless params[:original_image].present?

      continue params
    end

    def find_existing_image_transformation(params)
      p params[:specs]
      params[:image_transformation] = params[:original_image].transformations.find_by(specs: params[:specs].to_h)

      continue params
    end

    def create_image_transformation(params)
      return continue params[:image_transformation] if params[:image_transformation].present?

      image = build_image(params)
      params[:image_transformation] = ImageTransformation.create!(
                                        original: params[:original_image],
                                        specs: params[:specs].to_h,
                                        file: File.open(image.path),
                                      )

      continue params[:image_transformation]
    end

    private

    def build_image(params)
      image = MiniMagick::Image.open(params[:original_image].file.url)

      whitelisted_specs = params[:specs].slice(*ImageTransformation::SPECS_WHITELIST)
      whitelisted_specs.each do |spec, value|
        image.send(spec, value)
      end

      image
    end
  end
end
