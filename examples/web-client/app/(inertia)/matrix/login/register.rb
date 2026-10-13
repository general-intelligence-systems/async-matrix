# frozen_string_literal: true

# /matrix/login/register — Create account
#
# Fractal: login/greeter.{blp,rs} ("_Create Account")
#
# Fractal's greeter opens the homeserver's own registration page in a browser rather than carrying a
# form, because registration is a user-interactive flow whose stages the homeserver chooses. A web
# client can host the simple case, so this posts POST /register and reports what comes back.
#
# A homeserver which wants more than a password answers with a `flows` list instead of a session,
# which is the 401 the gem raises on. That is the point at which the browser is the right answer, so
# this says so rather than pretending to drive the stages.

get "/" do
  base_url = session[:matrix_base_url].to_s

  if base_url.empty?
    redirect("/matrix/login/homeserver", 303)
  end

  render(
    "matrix/login/register",
    homeserver: base_url,
    domain:     session[:matrix_domain],
    error:      session.delete(:matrix_register_error),
  )
end

post "/" do
  base_url = session[:matrix_base_url].to_s

  if base_url.empty?
    redirect("/matrix/login/homeserver", 303)
  end

  if params["password"].to_s.length < 8
    session[:matrix_register_error] = "that is shorter than eight characters"
    redirect("/matrix/login/register", 303)
  end

  answer = Matrix::Session.register(base_url, params["username"].to_s, params["password"].to_s)

  if answer.nil?
    session[:matrix_register_error] =
      "the homeserver would not register that here; it may need its own sign-up page"
    redirect("/matrix/login/register", 303)
  end

  store_session(base_url, answer)

  redirect("/matrix/login/setup", 303)
end

__END__

import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/reui/alert"
import { Button } from "@/components/ui/button"
import { Field, FieldDescription, FieldGroup, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { ShellHeader } from "@/components/admin/slots"

export default function MatrixLoginRegister({
  homeserver,
  domain,
  error,
}: {
  homeserver: string
  domain: string | null
  error: string | null
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title="Create account" />

      <ShellHeader>
        <Link href="/matrix/login" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="truncate text-sm font-medium">Create account</h1>
      </ShellHeader>

      <div className="mx-auto flex w-full max-w-md flex-col gap-6 p-6">
        <div className="flex flex-col gap-1">
          <h2 className="text-xl font-semibold tracking-tight">
            {domain ? `Create an account on ${domain}` : "Create an account"}
          </h2>
          <p className="font-mono text-xs text-muted-foreground">
            {homeserver.replace(/\/$/, "")}
          </p>
        </div>

        {error ? (
          <Alert variant="destructive">
            <AlertTitle>Not created</AlertTitle>
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        ) : null}

        <Form action="/matrix/login/register" method="post" className="flex flex-col gap-4">
          {({ processing }) => (
            <>
              <FieldGroup>
                <Field>
                  <FieldLabel htmlFor="username">Matrix Username</FieldLabel>
                  <Input
                    id="username"
                    name="username"
                    autoFocus
                    autoCapitalize="none"
                    spellCheck={false}
                  />
                  <FieldDescription>The localpart, without the leading @.</FieldDescription>
                </Field>
                <Field>
                  <FieldLabel htmlFor="password">Password</FieldLabel>
                  <Input
                    id="password"
                    name="password"
                    type="password"
                    autoComplete="new-password"
                  />
                  <FieldDescription>At least eight characters.</FieldDescription>
                </Field>
              </FieldGroup>

              <Button type="submit" disabled={processing} className="self-center">
                Create account
              </Button>
            </>
          )}
        </Form>
      </div>
    </div>
  )
}
