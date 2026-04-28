-- Allow admins to update any vendor row (needed for approval flow)
-- Without this, admin approval updates vendor_applications but silently
-- fails to set vendors.approved = true due to RLS blocking
CREATE POLICY "Admins update any vendor"
  ON vendors
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
