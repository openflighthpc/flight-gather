def between(string, s1, s2) # Returns the contents of string between the last instance of s1 and the next subsequent instance of s2
  if string.include? s1 and string.split(s1).last.include? s2
    string.split(s1).last.split(s2).first
  else ""
  end
end
