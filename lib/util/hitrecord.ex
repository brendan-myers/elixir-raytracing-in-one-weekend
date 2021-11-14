defmodule HitRecord do
  require Ray
  require Vector

  def hittable_list_hit(objects, ray, t_min \\ 0.001, t_max \\ 999999) do
    hittable_list_hit(objects, ray, t_min, t_max, {:miss})
  end
  def hittable_list_hit([], _ray, _t_min, _t_closest, hit_record) do
    hit_record
  end
  def hittable_list_hit([object|objects], ray, t_min, t_closest, hit_record) do
    rec = hit(object, ray, t_min, t_closest)

    case rec do
      {:hit, details} ->
        hittable_list_hit(objects, ray, t_min, details.t, rec)
      {:miss} ->
        hittable_list_hit(objects, ray, t_min, t_closest, hit_record)
    end
  end

  # def hit(object.type)
  def hit(object, ray, t_min, t_max) do
    {center, radius} = object.params

    oc = ray.origin |> Vector.sub(center)
    a = ray.direction |> Vector.length_squared()
    half_b = oc |> Vector.dot(ray.direction)
    c = (oc |> Vector.length_squared()) - radius*radius
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
        p = ray |> Ray.ray_at(t)
        {normal, front_face} = p
        |> Vector.sub(center)
        |> Vector.divide(radius)
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

  def set_face_normal(outward_normal, ray) do
    front_face = ray.direction |> Vector.dot(outward_normal)

    if front_face < 0 do
      {outward_normal, true}
    else
      {outward_normal |> Vector.mul(-1), false}
    end
  end

end
