defmodule Raytracer.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  # import Scenic.Components

  def init(_, opts) do
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    params = %{
      offsets: {0, 0, 0},
      fov_offset: 0,
      pitch: 0,
      yaw: 0,
      roll: 0
    }

    graph = draw(width, height, params)

    state = %{
      graph: graph,
      params: params,
      width: width,
      height: height
    }

    {:ok, state, push: graph}
  end

  def draw(width, height, params) do
    # objects in the scene
    hit_list = [
      %{
        # left
        type: :sphere,
        params: {vec3(-1, 0, -1), 0.5},
        # material: material_default(colour(0.8, 0, 0))
        material: material_dielectric(1.5)
      },
      %{
        # left
        type: :sphere,
        params: {vec3(-1, 0, -1), 0.4},
        material: material_dielectric(1.5)
      },
      %{
        # center
        type: :sphere,
        params: {vec3(0, 0, -1), 0.5},
        material: material_default(colour(0.1, 0.2, 0.5))
      },
      %{
        # right
        type: :sphere,
        params: {vec3(1, 0, -1), 0.5},
        material: material_metal(colour(0.8, 0.6, 0.2), 1)
      },
      %{
        # ground
        type: :sphere,
        params: {vec3(0, -100.5, -1), 100},
        material: material_default(colour(0.8, 0.8, 0))
      }
    ]

    pixel_n = 200 # number of pixels horizontally/vertically, ie resolution

    three_d = false

    aspect_ratio = width / height
    viewport_height = 2
    viewport_width = if three_d, do: aspect_ratio * viewport_height / 2 , else: aspect_ratio * viewport_height
    focal_length = 1 + params.fov_offset
    {x, y, z} = params.offsets
    eye_spacing = 0.05

    if three_d do
      camera_1 = camera(vec3(-eye_spacing+x, 0+y, 0+z), viewport_width, viewport_height,
        focal_length, params.pitch, params.yaw, params.roll)
      camera_2 = camera(vec3(eye_spacing+x, 0+y, 0+z), viewport_width, viewport_height,
        focal_length, params.pitch, params.yaw, params.roll)

      draw(Graph.build(), width/2, height, pixel_n, 0, camera_1, hit_list)
        |> draw(width/2, height, pixel_n, width/2, camera_2, hit_list)
    else
      camera = camera(vec3(0+x, 0+y, 0+z), viewport_width, viewport_height,
        focal_length, params.pitch, params.yaw, params.roll)

      draw(Graph.build(), width, height, pixel_n, 0, camera, hit_list)
    end
  end

  def draw(graph, width, height, pixel_n, offset, camera, hit_list) do
    pixel_sz = width / pixel_n

    draw_loop_j(graph, width, height, pixel_sz, offset, camera, hit_list, width/pixel_sz, height/pixel_sz)
  end
  def draw_loop_j(graph, width, height, pixel_sz, offset, camera, hit_list, i, j) do

    case {j} do
      {x} when x<0 ->
        graph
      {_} ->
        Logger.info("j: #{inspect(j)}")

        updated_graph = draw_loop_i(graph, width, height, pixel_sz, offset, camera, hit_list, i, j)
        draw_loop_j(updated_graph, width, height, pixel_sz, offset, camera, hit_list, i, j-1)
    end
  end
  def draw_loop_i(graph, width, height, pixel_sz, offset, camera, hit_list, i, j) do

    case {i} do
      {x} when x<0 ->
        graph
      {_} ->
        samples = 20

        pixel_colour = sample_pixel(camera, i, j, width, height, pixel_sz, hit_list, samples)
        |> colour

        # flip the image the right way up!
        flip_j = height/pixel_sz - j

        updated_graph = draw_pixel(graph, i, flip_j, pixel_colour, pixel_sz, offset, samples)

        draw_loop_i(updated_graph, width, height, pixel_sz, offset, camera, hit_list, i-1, j)
    end
  end

  def draw_pixel(graph, x, y, colour, pixel_sz, offset, samples) do
    scale = 1 / samples

    r_unscaled = :math.sqrt(colour.r * scale) |> clamp(0, 1)
    g_unscaled = :math.sqrt(colour.g * scale) |> clamp(0, 1)
    b_unscaled = :math.sqrt(colour.b * scale) |> clamp(0, 1)

    r = r_unscaled * 255 |> trunc
    g = g_unscaled * 255 |> trunc
    b = b_unscaled * 255 |> trunc

    x_off = x * pixel_sz + offset
    y_off = y * pixel_sz

    graph |> rect({pixel_sz, pixel_sz}, fill: {r, g, b}, translate: {x_off, y_off})
  end

  def sample_pixel(camera, i, j, width, height, pixel_sz, hit_list, samples) do
    sample_pixel(camera, i, j, width, height, pixel_sz, hit_list, vec3(0, 0, 0), samples)
  end

  def sample_pixel(camera, i, j, width, height, pixel_sz, hit_list, colour, samples) do
    case samples do
      x when x<=0 ->
        colour
      _ ->
        u = (i + :rand.uniform) / (width/pixel_sz)
        v = (j + :rand.uniform) / (height/pixel_sz)

        r = camera_get_ray(camera, u, v)
        pixel_colour = ray_colour(r, hit_list, 50)
        |> vec_add(colour)

        sample_pixel(camera, i, j, width, height, pixel_sz, hit_list, pixel_colour, samples-1)
    end
  end

  ###############################
  #
  # Vector

  def vec3(x, y, z) do
    %{
      x: x,
      y: y,
      z: z
    }
  end
  def vec3_random() do
    %{
      x: :rand.uniform,
      y: :rand.uniform,
      z: :rand.uniform,
    }
  end
  def vec3_random(min, max) do
    %{
      x: random(min, max),
      y: random(min, max),
      z: random(min, max),
    }
  end
  def vec_add(v1, v2) do
    %{
      x: v1.x + v2.x,
      y: v1.y + v2.y,
      z: v1.z + v2.z
    }
  end
  def vec_sub(v1, v2) do
    %{
      x: v1.x - v2.x,
      y: v1.y - v2.y,
      z: v1.z - v2.z
    }
  end
  def vec_mul(v, t) do
    %{
      x: v.x * t,
      y: v.y * t,
      z: v.z * t
    }
  end
  def vec_div(v, t) do
    vec_mul(v, 1/t)
  end
  def vec_length(v) do
    :math.sqrt(vec_length_squared(v))
  end
  def vec_length_squared(v) do
    v.x*v.x + v.y*v.y + v.z*v.z
  end
  def vec_element_mul(v1, v2) do
    %{
      x: v1.x * v2.x,
      y: v1.y * v2.y,
      z: v1.z * v2.z
    }
  end

  ### Helpers

  def dot(v1, v2) do
    v1.x*v2.x + v1.y*v2.y + v1.z*v2.z
  end
  def cross(v1, v2) do
    %{
      x: v1.y*v2.z - v1.z*v2.y,
      y: v1.z*v2.x - v1.x*v2.z,
      z: v1.x*v2.y - v1.y*v2.x
    }
  end
  def unit_vector(v) do
    vec_div(v, vec_length(v))
  end
  def random_in_unit_sphere() do
    v = vec3_random()

    if vec_length_squared(v) < 1 do
      v
    else
      random_in_unit_sphere()
    end
  end
  def random_unit_vector() do
    random_in_unit_sphere() |> unit_vector()
  end
  def near_zero(v) do
    s = 1.0e-18

    (abs(v.x) < s) and (abs(v.y) < s) and (abs(v.z) < s)
  end
  def reflect(v, n) do
    v
    |> vec_sub(
      n |> vec_mul(2 * dot(v, n))
    )
  end
  def refract(uv, n, etai_over_etat) do
    cos_theta = uv
    |> vec_mul(-1)
    |> dot(n)
    |> min(1)

    r_out_perp = n
    |> vec_mul(cos_theta)
    |> vec_add(uv)
    |> vec_mul(etai_over_etat)

    r_out_parallel = n
    |> vec_mul(
      -:math.sqrt(
        abs(
          1 - vec_length_squared(r_out_perp)
        )
      )
    )

    r_out_perp |> vec_add(r_out_parallel)
  end
  def reflectance(cosine, ref_idx) do
    r0 = (1 - ref_idx) / (1 + ref_idx)
    r0_sq = r0*r0
    r0 + (1 - r0) * :math.pow(1 - cosine, 5)
  end


  ###############################
  #
  # Colour

  def colour(r, g, b) do
    vec3(r, g, b)
  end
  def colour(v) do
    %{
      r: v.x,
      g: v.y,
      b: v.z
    }
  end


  ###############################
  #
  # Materials

  def material_default() do
    material_default(vec3(0, 0, 0))
  end
  def material_default(attenuation) do
    %{
      attenuation: attenuation,
      scatter: fn(_ray, rec) ->
        scatter_d = rec.normal |> vec_add(random_unit_vector())
        scatter_direction = if near_zero(scatter_d), do: rec.normal, else: scatter_d
        {true, ray(rec.p, scatter_direction)}
      end
    }
  end

  def material_metal() do
    material_metal(vec3(0, 0, 0), 0)
  end
  def material_metal(attenuation) do
    material_metal(attenuation, 0)
  end
  def material_metal(attenuation, fuzz) do
    %{
      attenuation: attenuation,
      fuzz: fuzz,
      scatter: fn(ray, rec) ->
        reflected = ray.direction
        |> unit_vector()
        |> reflect(rec.normal)

        scattered = ray(rec.p, reflected
          |> vec_add(
            random_in_unit_sphere() |> vec_mul(clamp(fuzz, 0, 1) )
          ))
        scatter = scattered.direction |> dot(rec.normal)
        {scatter > 0, scattered}
      end
    }
  end

  def material_dielectric(index_of_refraction) do
    %{
      attenuation: colour(1, 1, 1),
      scatter: fn(ray, rec) ->
        refraction_ratio = if rec.front_face do
          1.0 / index_of_refraction
        else
          index_of_refraction
        end

        unit_direction = ray.direction |> unit_vector()

        cos_theta = unit_direction
        |> vec_mul(-1)
        |> dot(rec.normal)
        |> min(1)

        sin_theta = :math.sqrt(1 - cos_theta*cos_theta)

        cannot_refract = refraction_ratio * sin_theta > 1

        direction = if cannot_refract || reflectance(cos_theta, refraction_ratio) > :random.uniform() do
          reflect(unit_direction, rec.normal)
        else
          refract(unit_direction, rec.normal, refraction_ratio)
        end

        {true, ray(rec.p, direction)}
      end
    }
  end

  ###############################
  #
  # Camera

  def camera(origin, viewport_width, viewport_height, focal_length, pitch, yaw, roll) do
    horizontal = vec3(viewport_width, 0, 0)
    vertical = vec3(0, viewport_height, 0)
    lower_left_corner = origin
      |> vec_sub(vec_div(horizontal, 2))
      |> vec_sub(vec_div(vertical, 2))
      |> vec_sub(vec3(0, 0, focal_length))

    %{
      origin: origin,
      horizontal: horizontal,
      vertical: vertical,
      lower_left_corner: lower_left_corner,
      pitch: pitch,
      yaw: yaw,
      roll: roll
    }
  end

  def camera_get_ray(camera, u, v) do
    pitch_radians = degrees_to_radians(camera.pitch)
    yaw_radians = degrees_to_radians(camera.yaw)

    direction = camera.lower_left_corner
    |> vec_add(vec_mul(camera.horizontal, u))
    |> vec_add(vec_mul(camera.vertical, v))
    |> vec_sub(camera.origin)

    ray(camera.origin, direction)
  end

  ###############################
  #
  # Ray

  def ray(origin, direction) do
    %{
      origin: origin,
      direction: direction
    }
  end
  def ray_at(ray, t) do
    vec_mul(ray.direction, t)
    |> vec_add(ray.origin)
  end
  def ray_colour(_ray, _hit_list, 0) do
    colour(0, 0, 0)
  end
  def ray_colour(ray, hit_list, depth) do
    case hittable_list_hit(hit_list, ray, 0.001, 999999) do
      {:hit, rec} ->
        {scatter, v} = rec.material.scatter.(ray, rec)
        if scatter do
          ray_colour(v, hit_list, depth-1)
          |> vec_element_mul(rec.material.attenuation)
        else
          colour(0, 0, 0)
        end
      _ ->
        unit_direction = unit_vector(ray.direction)
        t = 0.5 * (unit_direction.y + 1)

        colour_1 = colour(1.0, 1.0, 1.0)
        colour_2 = colour(0.5, 0.7, 1.0)

        colour_1
        |> vec_mul((1-t))
        |> vec_add(
          colour_2
          |> vec_mul(t))
    end
  end


  ###############################
  #
  # Hit Record

  def set_face_normal(outward_normal, ray) do
    front_face = ray.direction |> dot(outward_normal)

    if front_face < 0 do
      {outward_normal, true}
    else
      # Logger.info("DOES THIS HAPPEN")
      {outward_normal |> vec_mul(-1), false}
    end
  end

  # def hit(object.type)
  def hit(object, ray, t_min, t_max) do
    {center, radius} = object.params

    oc = ray.origin |> vec_sub(center)
    a = ray.direction |> vec_length_squared()
    half_b = oc |> dot(ray.direction)
    c = (oc |> vec_length_squared()) - radius*radius
    disciminant = half_b*half_b - a*c

    if disciminant < 0 do
      {:miss}
    else
      # find the nearest root that lies in the acceptable range
      sqrtd = :math.sqrt(disciminant)
      root_1 = (-half_b - sqrtd) / a
      root_2 = (-half_b + sqrtd) / a

      root = if root_1 < t_min || t_max < root_1 do
        if root_2 < t_min || t_max < root_2 do
          nil
        else
          root_2
        end
      else
        root_1
      end

      if root == nil do
        {:miss}
      else
        t = root
        p = ray |> ray_at(t)
        {normal, front_face} = p
        |> vec_sub(center)
        |> vec_div(radius)
        |> set_face_normal(ray)

        hit_record = %{
          t: t,
          p: p,
          normal: normal,
          material: object.material,
          front_face: front_face
        }

        {:hit, hit_record}
      end
    end
  end


  ###############################
  #
  # Hittable list
  def hittable_list_hit(objects, ray, t_min, t_max) do
    hittable_list_hit(objects, ray, t_min, t_max, nil)
  end
  def hittable_list_hit([object|objects], ray, t_min, t_closest, hit_record) do
    rec = hit(object, ray, t_min, t_closest)

    case rec do
      {:hit, details} ->
        hittable_list_hit(objects, ray, t_min, details.t, rec)
      _ ->
        hittable_list_hit(objects, ray, t_min, t_closest, hit_record)
    end


  end
  def hittable_list_hit([], _ray, _t_min, _t_closest, hit_record) do
    hit_record
  end


  ###############################
  #
  # Utilities

  def degrees_to_radians(degrees) do
    degrees * :math.pi / 180.0
  end

  def random(min, max) do
    min + (max-min) * :rand.uniform
  end

  def clamp(x, min, max) do
    case x do
      x when x < min ->
        min
      x when x > max ->
        max
      _ ->
        x
    end
  end


  ###############################
  #
  # Events

  def handle_input(event, _context, state) do
    offset_n = 0.1
    fov_n = 0.1
    pitch_n = 0.5
    yaw_n = 0.5
    roll_n = 0.5

    case event do
      {:key, {key_pressed, :press, _}} ->
        {x, y, z} = state.params.offsets

        left = if key_pressed == "left", do: -offset_n, else: 0
        right = if key_pressed == "right", do: offset_n, else: 0
        forward = if key_pressed == "up", do: -offset_n, else: 0
        backward = if key_pressed == "down", do: offset_n, else: 0
        up = if key_pressed == "[", do: offset_n, else: 0
        down = if key_pressed == "]", do: -offset_n, else: 0
        fov_inc = if key_pressed == "=", do: fov_n, else: 0
        fov_dec = if key_pressed == "-", do: -fov_n, else: 0
        pitch_inc = if key_pressed == "I", do: -pitch_n, else: 0
        pitch_dec = if key_pressed == "K", do: pitch_n, else: 0
        yaw_inc = if key_pressed == "J", do: yaw_n, else: 0
        yaw_dec = if key_pressed == "L", do: -yaw_n, else: 0
        roll_inc = if key_pressed == "U", do: roll_n, else: 0
        roll_dec = if key_pressed == "O", do: -roll_n, else: 0

        offsets = {
          x + left + right,
          y + up + down,
          z + backward + forward
        }
        fov_offset = state.params.fov_offset + fov_inc + fov_dec
        pitch = state.params.pitch + pitch_inc + pitch_dec
        yaw = state.params.yaw + yaw_inc + yaw_dec
        roll = state.params.roll + roll_inc + roll_dec
        params = %{
          offsets: offsets,
          fov_offset: fov_offset,
          pitch: pitch,
          yaw: yaw,
          roll: roll
        }

        graph = draw(state.width, state.height, params)

        new_state = %{
          graph: graph,
          params: params,
          width: state.width,
          height: state.height
        }

        {:noreply, new_state, push: graph}
      _ ->
        {:noreply, state}
    end
  end
end
