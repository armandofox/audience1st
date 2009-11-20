module Utils

  # given an array of objects and a block expression that returns 'true' if
  # two of the objects are equivalent, return a new array of length N
  # where N is the number of *unique* elements in the input array and
  # each element is [obj,count]

  def group_and_count(array,&blk)
    newarray = []
    last = nil
    array.each do |e|
      if last && blk.call(e,last)     # collapse
          newarray[newarray.size-1][1] += 1
      else
        newarray << [e,1]
        last = e
      end
    end
    newarray
  end
  
end

  
